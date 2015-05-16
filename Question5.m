function cout = Question5(donnees,epsilon)
d = importdata(donnees);
d.demande= d.demande + epsilon*d.delta_demande
c = [d.cout_materiaux  d.cout_stockage  d.cout_materiaux+(d.cout_heure_sup*(d.duree_assemblage/60))  d.cout_sous_traitant  d.cout_retard];
NBRE_VAR = 5;
LengthC = NBRE_VAR*d.T;
C=c;
for i = 1:d.T-1
C = [C c];
end

%%Matrice des contraintes d'�galit� Ax=b

Aequal = sparse(d.T,d.T*NBRE_VAR);
bequal = zeros(1,d.T);

Aequal(1,1:5) = [1 -1 1 1 1]; %pas de retard � rattraper ni de stock pour compenser
for i = 2:d.T
    Aequal(i,(1+NBRE_VAR*(i-1)):(NBRE_VAR*(i-1)+5)) = [1 -1 1 1 1];
    Aequal(i,NBRE_VAR*(i-1)) = -1;
    Aequal(i,(NBRE_VAR*(i-1))-3) = 1;
    bequal(i) = d.demande(i);
end
bequal(1) = d.demande(1)-d.stock_initial; % on ajoute le stock initial � la premi�re �galit�s
%Aequal(d.T,(NBRE_VAR*d.T)) = 0; 

%Matrice des contraintes d'in�galit� Ax<=b
Aineq = sparse(3*d.T, d.T*NBRE_VAR);
bineq = zeros(1,3*d.T);

for i = 2:d.T
    Aineq(i, ((NBRE_VAR*(i-1)+1)):((NBRE_VAR*(i-1)+5))) = [-1 0 -1 -1 0]; 
    Aineq(i, (NBRE_VAR*i)) = 1;
    %Aineq(i, (NBRE_VAR*i -3)) = 1;
    bineq(1,i) = 0;
end

Aineq(1, NBRE_VAR-1) = 1;
Aineq(1, NBRE_VAR-3) = 0;
Aineq(1, NBRE_VAR) = 0;

for i = d.T+1:2*d.T
    Aineq(i, (NBRE_VAR*(i-d.T-1)+1)) = 1;
    bineq(1,i) = (d.nb_ouvriers*35)/(d.duree_assemblage/60);
end
for i = 2*d.T+1:3*d.T
    Aineq(i, (NBRE_VAR*(i-2*d.T-1)+3)) = 1;
    bineq(1,i) = (d.nb_ouvriers*d.nb_max_heure_sup)/(d.duree_assemblage/60);
end

ub = zeros(1,LengthC); % Upper bound
lb = zeros(1,LengthC); % Lower bound
ub(1) = inf;
for i = (5:5:75)
    ub(i-1) = d.nb_max_sous_traitant;
    ub(i-4) = (d.nb_ouvriers*35)/(d.duree_assemblage/60);
    ub(i-2) = (d.nb_ouvriers*d.nb_max_heure_sup)/(d.duree_assemblage/60);
    ub(i) = d.demande(i/5);
    ub(i-3) = inf;
    if i == LengthC 
        %retour au Stock initial obligatoire
        ub(i-3) = d.stock_initial;
        lb(i-3) = d.stock_initial;
        % pas de retard la derni�re semaine
        ub(i) = 0;
    end
end
[m, n] = size(Aineq);
[meq, neq] = size(Aequal);
A_dual = [Aineq;Aequal]';
f_dual = [bineq bequal];
b_dual = C;
ub_dual = [zeros(1, m) inf(1, meq)]';
lb_dual = zeros(size(ub_dual));
options = optimoptions(@linprog, 'Algorithm', 'simplex');%Sol enti�re si elle existe
%tab = reshape(linprog(-f_dual, A_dual, b_dual, [], [], [], ub_dual),5,15)';
%[x,f] = linprog(C,Aineq,bineq,Aequal,bequal,lb,ub,zeros(1,LengthC),options);
[x,f] = linprog(-f_dual, A_dual, b_dual, [], [], [], ub_dual); %,zeros(1,LengthC),options
cout = f_dual*x + (d.cout_horaire*d.nb_ouvriers*35*d.T); %Ajout des salaires r�guliers