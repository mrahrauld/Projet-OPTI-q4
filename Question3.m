function cout = Question3(donnees)
d = importdata(donnees);
%Matrice de la fonction objectif
c = [d.cout_materiaux  d.cout_stockage  d.cout_materiaux+(d.cout_heure_sup*(d.duree_assemblage/60))  d.cout_sous_traitant  d.cout_retard];
NBRE_VAR = 5;
LengthC = NBRE_VAR*d.T;
C=c;
% il y a 5*d.T nombre de variable dans la fonction objectif
for i = 1:d.T-1
C = [C c];
end

%%% -/ Matrice des contraintes d'égalité Ax=b \- %%%

Aequal = sparse(d.T,d.T*NBRE_VAR);
bequal = zeros(1,d.T);

Aequal(1,1:5) = [1 -1 1 1 1]; %pas de retard à rattraper ni de stock pour compenser
bequal(1) = d.demande(1)-d.stock_initial; % on ajoute le stock initial à la première égalitée
for i = 2:d.T
    Aequal(i,(1+NBRE_VAR*(i-1)):(NBRE_VAR*(i-1)+5)) = [1 -1 1 1 1];
    Aequal(i,NBRE_VAR*(i-1)) = -1; %retard de la semaine précédente
    Aequal(i,(NBRE_VAR*(i-1))-3) = 1; %Stock de la semaine précédente
    bequal(i) = d.demande(i);
end

%%% -/ Matrice des contraintes d'inégalité Ax<=b \- %%%

Aineq = sparse(d.T, d.T*NBRE_VAR);
bineq = zeros(1,d.T);

for i = 2:d.T
    Aineq(i, ((NBRE_VAR*(i-1)+1)):((NBRE_VAR*(i-1)+5))) = [-1 0 -1 -1 0]; 
    Aineq(i, (NBRE_VAR*i)) = 1;
    bineq(1,i) = 0;
end
Aineq(1, NBRE_VAR-1) = 1; 
Aineq(1, NBRE_VAR-3) = 0;
Aineq(1, NBRE_VAR) = 0;

%%% -/ Valeurs à ne pas dépasser \- %%%

ub = zeros(1,LengthC); % Upper bound
lb = zeros(1,LengthC); % Lower bound
for i = (NBRE_VAR:NBRE_VAR:d.T*NBRE_VAR)
    ub(i-1) = d.nb_max_sous_traitant; %nombre max d'unitées sous traitées
    ub(i-4) = (d.nb_ouvriers*35)/(d.duree_assemblage/60); %nombre max d'unitées produites à heures normales
    ub(i-2) = (d.nb_ouvriers*d.nb_max_heure_sup)/(d.duree_assemblage/60);%nombre max d'unitées produites à heures supplémentaires
    ub(i) = d.demande(i/5); % le retard ne peut être plus important que la demande de la semaine actuel, sinon des produits sont mis 2 semaines en retard
    ub(i-3) = inf; %pas de borne supérieure de stockage
    if i == LengthC 
        %retour au Stock initial obligatoire
        ub(i-3) = d.stock_initial;
        lb(i-3) = d.stock_initial;
        % pas de retard la dernière semaine
        ub(i) = 0;
    end
end
    
%%% -/ Calcul de la Solution \- %%%

options = optimoptions(@linprog, 'Algorithm', 'simplex');%option Simplex pour trouver une solution entière
[x,f] = linprog(C,Aineq,bineq,Aequal,bequal,lb,ub,zeros(1,LengthC),options);
tab = reshape(x,NBRE_VAR,d.T)';
legende =[' à cout normal '  ' Stock en fin de semaine ' ' en heure supp ' ' sous-traités ' ' Reportés ' ' Demande '];
tab(1:d.T,6)=d.demande

cout = f + (d.cout_horaire*d.nb_ouvriers*35*d.T); %Ajout des salaires réguliers
